
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2011-02-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearch/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
                           "us-east-1": "cloudsearch.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudsearch.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearch.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearch.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearch"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCreateDomain_594045 = ref object of OpenApiRestCall_593437
proc url_PostCreateDomain_594047(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_594046(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594048 = query.getOrDefault("Action")
  valid_594048 = validateParameter(valid_594048, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_594048 != nil:
    section.add "Action", valid_594048
  var valid_594049 = query.getOrDefault("Version")
  valid_594049 = validateParameter(valid_594049, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594049 != nil:
    section.add "Version", valid_594049
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
  var valid_594050 = header.getOrDefault("X-Amz-Date")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Date", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Security-Token")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Security-Token", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Content-Sha256", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Algorithm")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Algorithm", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Signature")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Signature", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-SignedHeaders", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Credential")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Credential", valid_594056
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594057 = formData.getOrDefault("DomainName")
  valid_594057 = validateParameter(valid_594057, JString, required = true,
                                 default = nil)
  if valid_594057 != nil:
    section.add "DomainName", valid_594057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594058: Call_PostCreateDomain_594045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_594058.validator(path, query, header, formData, body)
  let scheme = call_594058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594058.url(scheme.get, call_594058.host, call_594058.base,
                         call_594058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594058, url, valid)

proc call*(call_594059: Call_PostCreateDomain_594045; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594060 = newJObject()
  var formData_594061 = newJObject()
  add(formData_594061, "DomainName", newJString(DomainName))
  add(query_594060, "Action", newJString(Action))
  add(query_594060, "Version", newJString(Version))
  result = call_594059.call(nil, query_594060, nil, formData_594061, nil)

var postCreateDomain* = Call_PostCreateDomain_594045(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_594046,
    base: "/", url: url_PostCreateDomain_594047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_593774 = ref object of OpenApiRestCall_593437
proc url_GetCreateDomain_593776(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_593775(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593901 = query.getOrDefault("Action")
  valid_593901 = validateParameter(valid_593901, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_593901 != nil:
    section.add "Action", valid_593901
  var valid_593902 = query.getOrDefault("DomainName")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "DomainName", valid_593902
  var valid_593903 = query.getOrDefault("Version")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593903 != nil:
    section.add "Version", valid_593903
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

proc call*(call_593933: Call_GetCreateDomain_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_593933.validator(path, query, header, formData, body)
  let scheme = call_593933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593933.url(scheme.get, call_593933.host, call_593933.base,
                         call_593933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593933, url, valid)

proc call*(call_594004: Call_GetCreateDomain_593774; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594005 = newJObject()
  add(query_594005, "Action", newJString(Action))
  add(query_594005, "DomainName", newJString(DomainName))
  add(query_594005, "Version", newJString(Version))
  result = call_594004.call(nil, query_594005, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_593774(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_593775,
    base: "/", url: url_GetCreateDomain_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_594084 = ref object of OpenApiRestCall_593437
proc url_PostDefineIndexField_594086(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineIndexField_594085(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594087 = query.getOrDefault("Action")
  valid_594087 = validateParameter(valid_594087, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_594087 != nil:
    section.add "Action", valid_594087
  var valid_594088 = query.getOrDefault("Version")
  valid_594088 = validateParameter(valid_594088, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594088 != nil:
    section.add "Version", valid_594088
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
  var valid_594089 = header.getOrDefault("X-Amz-Date")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Date", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Security-Token")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Security-Token", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Content-Sha256", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Algorithm")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Algorithm", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Signature")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Signature", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-SignedHeaders", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Credential")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Credential", valid_594095
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  section = newJObject()
  var valid_594096 = formData.getOrDefault("IndexField.UIntOptions")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "IndexField.UIntOptions", valid_594096
  var valid_594097 = formData.getOrDefault("IndexField.TextOptions")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "IndexField.TextOptions", valid_594097
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594098 = formData.getOrDefault("DomainName")
  valid_594098 = validateParameter(valid_594098, JString, required = true,
                                 default = nil)
  if valid_594098 != nil:
    section.add "DomainName", valid_594098
  var valid_594099 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "IndexField.LiteralOptions", valid_594099
  var valid_594100 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "IndexField.IndexFieldType", valid_594100
  var valid_594101 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "IndexField.IndexFieldName", valid_594101
  var valid_594102 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_594102 = validateParameter(valid_594102, JArray, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "IndexField.SourceAttributes", valid_594102
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594103: Call_PostDefineIndexField_594084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_594103.validator(path, query, header, formData, body)
  let scheme = call_594103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594103.url(scheme.get, call_594103.host, call_594103.base,
                         call_594103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594103, url, valid)

proc call*(call_594104: Call_PostDefineIndexField_594084; DomainName: string;
          IndexFieldUIntOptions: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldIndexFieldType: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; Version: string = "2011-02-01";
          IndexFieldSourceAttributes: JsonNode = nil): Recallable =
  ## postDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  var query_594105 = newJObject()
  var formData_594106 = newJObject()
  add(formData_594106, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(formData_594106, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_594106, "DomainName", newJString(DomainName))
  add(formData_594106, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_594106, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_594105, "Action", newJString(Action))
  add(formData_594106, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_594105, "Version", newJString(Version))
  if IndexFieldSourceAttributes != nil:
    formData_594106.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  result = call_594104.call(nil, query_594105, nil, formData_594106, nil)

var postDefineIndexField* = Call_PostDefineIndexField_594084(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_594085, base: "/",
    url: url_PostDefineIndexField_594086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_594062 = ref object of OpenApiRestCall_593437
proc url_GetDefineIndexField_594064(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineIndexField_594063(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_594065 = query.getOrDefault("IndexField.TextOptions")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "IndexField.TextOptions", valid_594065
  var valid_594066 = query.getOrDefault("IndexField.LiteralOptions")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "IndexField.LiteralOptions", valid_594066
  var valid_594067 = query.getOrDefault("IndexField.UIntOptions")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "IndexField.UIntOptions", valid_594067
  var valid_594068 = query.getOrDefault("IndexField.IndexFieldType")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "IndexField.IndexFieldType", valid_594068
  var valid_594069 = query.getOrDefault("IndexField.SourceAttributes")
  valid_594069 = validateParameter(valid_594069, JArray, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "IndexField.SourceAttributes", valid_594069
  var valid_594070 = query.getOrDefault("IndexField.IndexFieldName")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "IndexField.IndexFieldName", valid_594070
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594071 = query.getOrDefault("Action")
  valid_594071 = validateParameter(valid_594071, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_594071 != nil:
    section.add "Action", valid_594071
  var valid_594072 = query.getOrDefault("DomainName")
  valid_594072 = validateParameter(valid_594072, JString, required = true,
                                 default = nil)
  if valid_594072 != nil:
    section.add "DomainName", valid_594072
  var valid_594073 = query.getOrDefault("Version")
  valid_594073 = validateParameter(valid_594073, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594073 != nil:
    section.add "Version", valid_594073
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
  var valid_594074 = header.getOrDefault("X-Amz-Date")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Date", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Security-Token")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Security-Token", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Content-Sha256", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Algorithm")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Algorithm", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Signature")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Signature", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-SignedHeaders", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Credential")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Credential", valid_594080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594081: Call_GetDefineIndexField_594062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_594081.validator(path, query, header, formData, body)
  let scheme = call_594081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594081.url(scheme.get, call_594081.host, call_594081.base,
                         call_594081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594081, url, valid)

proc call*(call_594082: Call_GetDefineIndexField_594062; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldLiteralOptions: string = "";
          IndexFieldUIntOptions: string = ""; IndexFieldIndexFieldType: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          IndexFieldIndexFieldName: string = "";
          Action: string = "DefineIndexField"; Version: string = "2011-02-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594083 = newJObject()
  add(query_594083, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_594083, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_594083, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(query_594083, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  if IndexFieldSourceAttributes != nil:
    query_594083.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_594083, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_594083, "Action", newJString(Action))
  add(query_594083, "DomainName", newJString(DomainName))
  add(query_594083, "Version", newJString(Version))
  result = call_594082.call(nil, query_594083, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_594062(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_594063, base: "/",
    url: url_GetDefineIndexField_594064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_594125 = ref object of OpenApiRestCall_593437
proc url_PostDefineRankExpression_594127(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineRankExpression_594126(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594128 = query.getOrDefault("Action")
  valid_594128 = validateParameter(valid_594128, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_594128 != nil:
    section.add "Action", valid_594128
  var valid_594129 = query.getOrDefault("Version")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594129 != nil:
    section.add "Version", valid_594129
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
  var valid_594130 = header.getOrDefault("X-Amz-Date")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Date", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Security-Token")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Security-Token", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Content-Sha256", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Algorithm")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Algorithm", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Signature")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Signature", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-SignedHeaders", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Credential")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Credential", valid_594136
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594137 = formData.getOrDefault("DomainName")
  valid_594137 = validateParameter(valid_594137, JString, required = true,
                                 default = nil)
  if valid_594137 != nil:
    section.add "DomainName", valid_594137
  var valid_594138 = formData.getOrDefault("RankExpression.RankName")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "RankExpression.RankName", valid_594138
  var valid_594139 = formData.getOrDefault("RankExpression.RankExpression")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "RankExpression.RankExpression", valid_594139
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594140: Call_PostDefineRankExpression_594125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_594140.validator(path, query, header, formData, body)
  let scheme = call_594140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594140.url(scheme.get, call_594140.host, call_594140.base,
                         call_594140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594140, url, valid)

proc call*(call_594141: Call_PostDefineRankExpression_594125; DomainName: string;
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = "";
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594142 = newJObject()
  var formData_594143 = newJObject()
  add(formData_594143, "DomainName", newJString(DomainName))
  add(formData_594143, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_594143, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_594142, "Action", newJString(Action))
  add(query_594142, "Version", newJString(Version))
  result = call_594141.call(nil, query_594142, nil, formData_594143, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_594125(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_594126, base: "/",
    url: url_PostDefineRankExpression_594127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_594107 = ref object of OpenApiRestCall_593437
proc url_GetDefineRankExpression_594109(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineRankExpression_594108(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594110 = query.getOrDefault("Action")
  valid_594110 = validateParameter(valid_594110, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_594110 != nil:
    section.add "Action", valid_594110
  var valid_594111 = query.getOrDefault("RankExpression.RankExpression")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "RankExpression.RankExpression", valid_594111
  var valid_594112 = query.getOrDefault("RankExpression.RankName")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "RankExpression.RankName", valid_594112
  var valid_594113 = query.getOrDefault("DomainName")
  valid_594113 = validateParameter(valid_594113, JString, required = true,
                                 default = nil)
  if valid_594113 != nil:
    section.add "DomainName", valid_594113
  var valid_594114 = query.getOrDefault("Version")
  valid_594114 = validateParameter(valid_594114, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594114 != nil:
    section.add "Version", valid_594114
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
  var valid_594115 = header.getOrDefault("X-Amz-Date")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Date", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Content-Sha256", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Algorithm")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Algorithm", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Signature")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Signature", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-SignedHeaders", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Credential")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Credential", valid_594121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594122: Call_GetDefineRankExpression_594107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_594122.validator(path, query, header, formData, body)
  let scheme = call_594122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594122.url(scheme.get, call_594122.host, call_594122.base,
                         call_594122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594122, url, valid)

proc call*(call_594123: Call_GetDefineRankExpression_594107; DomainName: string;
          Action: string = "DefineRankExpression";
          RankExpressionRankExpression: string = "";
          RankExpressionRankName: string = ""; Version: string = "2011-02-01"): Recallable =
  ## getDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   Action: string (required)
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594124 = newJObject()
  add(query_594124, "Action", newJString(Action))
  add(query_594124, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_594124, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_594124, "DomainName", newJString(DomainName))
  add(query_594124, "Version", newJString(Version))
  result = call_594123.call(nil, query_594124, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_594107(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_594108, base: "/",
    url: url_GetDefineRankExpression_594109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_594160 = ref object of OpenApiRestCall_593437
proc url_PostDeleteDomain_594162(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_594161(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594163 = query.getOrDefault("Action")
  valid_594163 = validateParameter(valid_594163, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_594163 != nil:
    section.add "Action", valid_594163
  var valid_594164 = query.getOrDefault("Version")
  valid_594164 = validateParameter(valid_594164, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594164 != nil:
    section.add "Version", valid_594164
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
  var valid_594165 = header.getOrDefault("X-Amz-Date")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Date", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Security-Token")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Security-Token", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Content-Sha256", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Algorithm")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Algorithm", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Signature")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Signature", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-SignedHeaders", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Credential")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Credential", valid_594171
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594172 = formData.getOrDefault("DomainName")
  valid_594172 = validateParameter(valid_594172, JString, required = true,
                                 default = nil)
  if valid_594172 != nil:
    section.add "DomainName", valid_594172
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594173: Call_PostDeleteDomain_594160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_594173.validator(path, query, header, formData, body)
  let scheme = call_594173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594173.url(scheme.get, call_594173.host, call_594173.base,
                         call_594173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594173, url, valid)

proc call*(call_594174: Call_PostDeleteDomain_594160; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594175 = newJObject()
  var formData_594176 = newJObject()
  add(formData_594176, "DomainName", newJString(DomainName))
  add(query_594175, "Action", newJString(Action))
  add(query_594175, "Version", newJString(Version))
  result = call_594174.call(nil, query_594175, nil, formData_594176, nil)

var postDeleteDomain* = Call_PostDeleteDomain_594160(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_594161,
    base: "/", url: url_PostDeleteDomain_594162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_594144 = ref object of OpenApiRestCall_593437
proc url_GetDeleteDomain_594146(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_594145(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594147 = query.getOrDefault("Action")
  valid_594147 = validateParameter(valid_594147, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_594147 != nil:
    section.add "Action", valid_594147
  var valid_594148 = query.getOrDefault("DomainName")
  valid_594148 = validateParameter(valid_594148, JString, required = true,
                                 default = nil)
  if valid_594148 != nil:
    section.add "DomainName", valid_594148
  var valid_594149 = query.getOrDefault("Version")
  valid_594149 = validateParameter(valid_594149, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594149 != nil:
    section.add "Version", valid_594149
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
  var valid_594150 = header.getOrDefault("X-Amz-Date")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Date", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Security-Token")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Security-Token", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Content-Sha256", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Algorithm")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Algorithm", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Signature")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Signature", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-SignedHeaders", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Credential")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Credential", valid_594156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594157: Call_GetDeleteDomain_594144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_594157.validator(path, query, header, formData, body)
  let scheme = call_594157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594157.url(scheme.get, call_594157.host, call_594157.base,
                         call_594157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594157, url, valid)

proc call*(call_594158: Call_GetDeleteDomain_594144; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594159 = newJObject()
  add(query_594159, "Action", newJString(Action))
  add(query_594159, "DomainName", newJString(DomainName))
  add(query_594159, "Version", newJString(Version))
  result = call_594158.call(nil, query_594159, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_594144(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_594145,
    base: "/", url: url_GetDeleteDomain_594146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_594194 = ref object of OpenApiRestCall_593437
proc url_PostDeleteIndexField_594196(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteIndexField_594195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594197 = query.getOrDefault("Action")
  valid_594197 = validateParameter(valid_594197, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_594197 != nil:
    section.add "Action", valid_594197
  var valid_594198 = query.getOrDefault("Version")
  valid_594198 = validateParameter(valid_594198, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594198 != nil:
    section.add "Version", valid_594198
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
  var valid_594199 = header.getOrDefault("X-Amz-Date")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Date", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Security-Token")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Security-Token", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Content-Sha256", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Algorithm")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Algorithm", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Signature")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Signature", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-SignedHeaders", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Credential")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Credential", valid_594205
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594206 = formData.getOrDefault("DomainName")
  valid_594206 = validateParameter(valid_594206, JString, required = true,
                                 default = nil)
  if valid_594206 != nil:
    section.add "DomainName", valid_594206
  var valid_594207 = formData.getOrDefault("IndexFieldName")
  valid_594207 = validateParameter(valid_594207, JString, required = true,
                                 default = nil)
  if valid_594207 != nil:
    section.add "IndexFieldName", valid_594207
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594208: Call_PostDeleteIndexField_594194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_594208.validator(path, query, header, formData, body)
  let scheme = call_594208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594208.url(scheme.get, call_594208.host, call_594208.base,
                         call_594208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594208, url, valid)

proc call*(call_594209: Call_PostDeleteIndexField_594194; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594210 = newJObject()
  var formData_594211 = newJObject()
  add(formData_594211, "DomainName", newJString(DomainName))
  add(formData_594211, "IndexFieldName", newJString(IndexFieldName))
  add(query_594210, "Action", newJString(Action))
  add(query_594210, "Version", newJString(Version))
  result = call_594209.call(nil, query_594210, nil, formData_594211, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_594194(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_594195, base: "/",
    url: url_PostDeleteIndexField_594196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_594177 = ref object of OpenApiRestCall_593437
proc url_GetDeleteIndexField_594179(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteIndexField_594178(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `IndexFieldName` field"
  var valid_594180 = query.getOrDefault("IndexFieldName")
  valid_594180 = validateParameter(valid_594180, JString, required = true,
                                 default = nil)
  if valid_594180 != nil:
    section.add "IndexFieldName", valid_594180
  var valid_594181 = query.getOrDefault("Action")
  valid_594181 = validateParameter(valid_594181, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_594181 != nil:
    section.add "Action", valid_594181
  var valid_594182 = query.getOrDefault("DomainName")
  valid_594182 = validateParameter(valid_594182, JString, required = true,
                                 default = nil)
  if valid_594182 != nil:
    section.add "DomainName", valid_594182
  var valid_594183 = query.getOrDefault("Version")
  valid_594183 = validateParameter(valid_594183, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594183 != nil:
    section.add "Version", valid_594183
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
  var valid_594184 = header.getOrDefault("X-Amz-Date")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Date", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Security-Token")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Security-Token", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Content-Sha256", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Algorithm")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Algorithm", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Signature")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Signature", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-SignedHeaders", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-Credential")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Credential", valid_594190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594191: Call_GetDeleteIndexField_594177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_594191.validator(path, query, header, formData, body)
  let scheme = call_594191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594191.url(scheme.get, call_594191.host, call_594191.base,
                         call_594191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594191, url, valid)

proc call*(call_594192: Call_GetDeleteIndexField_594177; IndexFieldName: string;
          DomainName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594193 = newJObject()
  add(query_594193, "IndexFieldName", newJString(IndexFieldName))
  add(query_594193, "Action", newJString(Action))
  add(query_594193, "DomainName", newJString(DomainName))
  add(query_594193, "Version", newJString(Version))
  result = call_594192.call(nil, query_594193, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_594177(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_594178, base: "/",
    url: url_GetDeleteIndexField_594179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_594229 = ref object of OpenApiRestCall_593437
proc url_PostDeleteRankExpression_594231(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteRankExpression_594230(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594232 = query.getOrDefault("Action")
  valid_594232 = validateParameter(valid_594232, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_594232 != nil:
    section.add "Action", valid_594232
  var valid_594233 = query.getOrDefault("Version")
  valid_594233 = validateParameter(valid_594233, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594233 != nil:
    section.add "Version", valid_594233
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
  var valid_594234 = header.getOrDefault("X-Amz-Date")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "X-Amz-Date", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-Security-Token")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Security-Token", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Content-Sha256", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Algorithm")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Algorithm", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Signature")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Signature", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-SignedHeaders", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Credential")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Credential", valid_594240
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594241 = formData.getOrDefault("DomainName")
  valid_594241 = validateParameter(valid_594241, JString, required = true,
                                 default = nil)
  if valid_594241 != nil:
    section.add "DomainName", valid_594241
  var valid_594242 = formData.getOrDefault("RankName")
  valid_594242 = validateParameter(valid_594242, JString, required = true,
                                 default = nil)
  if valid_594242 != nil:
    section.add "RankName", valid_594242
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594243: Call_PostDeleteRankExpression_594229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_594243.validator(path, query, header, formData, body)
  let scheme = call_594243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594243.url(scheme.get, call_594243.host, call_594243.base,
                         call_594243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594243, url, valid)

proc call*(call_594244: Call_PostDeleteRankExpression_594229; DomainName: string;
          RankName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_594245 = newJObject()
  var formData_594246 = newJObject()
  add(formData_594246, "DomainName", newJString(DomainName))
  add(query_594245, "Action", newJString(Action))
  add(formData_594246, "RankName", newJString(RankName))
  add(query_594245, "Version", newJString(Version))
  result = call_594244.call(nil, query_594245, nil, formData_594246, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_594229(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_594230, base: "/",
    url: url_PostDeleteRankExpression_594231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_594212 = ref object of OpenApiRestCall_593437
proc url_GetDeleteRankExpression_594214(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteRankExpression_594213(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RankName` field"
  var valid_594215 = query.getOrDefault("RankName")
  valid_594215 = validateParameter(valid_594215, JString, required = true,
                                 default = nil)
  if valid_594215 != nil:
    section.add "RankName", valid_594215
  var valid_594216 = query.getOrDefault("Action")
  valid_594216 = validateParameter(valid_594216, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_594216 != nil:
    section.add "Action", valid_594216
  var valid_594217 = query.getOrDefault("DomainName")
  valid_594217 = validateParameter(valid_594217, JString, required = true,
                                 default = nil)
  if valid_594217 != nil:
    section.add "DomainName", valid_594217
  var valid_594218 = query.getOrDefault("Version")
  valid_594218 = validateParameter(valid_594218, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594218 != nil:
    section.add "Version", valid_594218
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
  var valid_594219 = header.getOrDefault("X-Amz-Date")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Date", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Security-Token")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Security-Token", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Content-Sha256", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-Algorithm")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Algorithm", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Signature")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Signature", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-SignedHeaders", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Credential")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Credential", valid_594225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594226: Call_GetDeleteRankExpression_594212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_594226.validator(path, query, header, formData, body)
  let scheme = call_594226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594226.url(scheme.get, call_594226.host, call_594226.base,
                         call_594226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594226, url, valid)

proc call*(call_594227: Call_GetDeleteRankExpression_594212; RankName: string;
          DomainName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594228 = newJObject()
  add(query_594228, "RankName", newJString(RankName))
  add(query_594228, "Action", newJString(Action))
  add(query_594228, "DomainName", newJString(DomainName))
  add(query_594228, "Version", newJString(Version))
  result = call_594227.call(nil, query_594228, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_594212(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_594213, base: "/",
    url: url_GetDeleteRankExpression_594214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_594263 = ref object of OpenApiRestCall_593437
proc url_PostDescribeAvailabilityOptions_594265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAvailabilityOptions_594264(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594266 = query.getOrDefault("Action")
  valid_594266 = validateParameter(valid_594266, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_594266 != nil:
    section.add "Action", valid_594266
  var valid_594267 = query.getOrDefault("Version")
  valid_594267 = validateParameter(valid_594267, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594267 != nil:
    section.add "Version", valid_594267
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
  var valid_594268 = header.getOrDefault("X-Amz-Date")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Date", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Security-Token")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Security-Token", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Content-Sha256", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Algorithm")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Algorithm", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Signature")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Signature", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-SignedHeaders", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Credential")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Credential", valid_594274
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594275 = formData.getOrDefault("DomainName")
  valid_594275 = validateParameter(valid_594275, JString, required = true,
                                 default = nil)
  if valid_594275 != nil:
    section.add "DomainName", valid_594275
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594276: Call_PostDescribeAvailabilityOptions_594263;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594276.validator(path, query, header, formData, body)
  let scheme = call_594276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594276.url(scheme.get, call_594276.host, call_594276.base,
                         call_594276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594276, url, valid)

proc call*(call_594277: Call_PostDescribeAvailabilityOptions_594263;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594278 = newJObject()
  var formData_594279 = newJObject()
  add(formData_594279, "DomainName", newJString(DomainName))
  add(query_594278, "Action", newJString(Action))
  add(query_594278, "Version", newJString(Version))
  result = call_594277.call(nil, query_594278, nil, formData_594279, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_594263(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_594264, base: "/",
    url: url_PostDescribeAvailabilityOptions_594265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_594247 = ref object of OpenApiRestCall_593437
proc url_GetDescribeAvailabilityOptions_594249(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAvailabilityOptions_594248(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594250 = query.getOrDefault("Action")
  valid_594250 = validateParameter(valid_594250, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_594250 != nil:
    section.add "Action", valid_594250
  var valid_594251 = query.getOrDefault("DomainName")
  valid_594251 = validateParameter(valid_594251, JString, required = true,
                                 default = nil)
  if valid_594251 != nil:
    section.add "DomainName", valid_594251
  var valid_594252 = query.getOrDefault("Version")
  valid_594252 = validateParameter(valid_594252, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594252 != nil:
    section.add "Version", valid_594252
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
  var valid_594253 = header.getOrDefault("X-Amz-Date")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Date", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Security-Token")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Security-Token", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Content-Sha256", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Algorithm")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Algorithm", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Signature")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Signature", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-SignedHeaders", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Credential")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Credential", valid_594259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594260: Call_GetDescribeAvailabilityOptions_594247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594260.validator(path, query, header, formData, body)
  let scheme = call_594260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594260.url(scheme.get, call_594260.host, call_594260.base,
                         call_594260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594260, url, valid)

proc call*(call_594261: Call_GetDescribeAvailabilityOptions_594247;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594262 = newJObject()
  add(query_594262, "Action", newJString(Action))
  add(query_594262, "DomainName", newJString(DomainName))
  add(query_594262, "Version", newJString(Version))
  result = call_594261.call(nil, query_594262, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_594247(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_594248, base: "/",
    url: url_GetDescribeAvailabilityOptions_594249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_594296 = ref object of OpenApiRestCall_593437
proc url_PostDescribeDefaultSearchField_594298(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDefaultSearchField_594297(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594299 = query.getOrDefault("Action")
  valid_594299 = validateParameter(valid_594299, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_594299 != nil:
    section.add "Action", valid_594299
  var valid_594300 = query.getOrDefault("Version")
  valid_594300 = validateParameter(valid_594300, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594300 != nil:
    section.add "Version", valid_594300
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
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Security-Token")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Security-Token", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Content-Sha256", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Algorithm")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Algorithm", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Signature")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Signature", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-SignedHeaders", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Credential")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Credential", valid_594307
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594308 = formData.getOrDefault("DomainName")
  valid_594308 = validateParameter(valid_594308, JString, required = true,
                                 default = nil)
  if valid_594308 != nil:
    section.add "DomainName", valid_594308
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594309: Call_PostDescribeDefaultSearchField_594296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_594309.validator(path, query, header, formData, body)
  let scheme = call_594309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594309.url(scheme.get, call_594309.host, call_594309.base,
                         call_594309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594309, url, valid)

proc call*(call_594310: Call_PostDescribeDefaultSearchField_594296;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594311 = newJObject()
  var formData_594312 = newJObject()
  add(formData_594312, "DomainName", newJString(DomainName))
  add(query_594311, "Action", newJString(Action))
  add(query_594311, "Version", newJString(Version))
  result = call_594310.call(nil, query_594311, nil, formData_594312, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_594296(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_594297, base: "/",
    url: url_PostDescribeDefaultSearchField_594298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_594280 = ref object of OpenApiRestCall_593437
proc url_GetDescribeDefaultSearchField_594282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDefaultSearchField_594281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594283 = query.getOrDefault("Action")
  valid_594283 = validateParameter(valid_594283, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_594283 != nil:
    section.add "Action", valid_594283
  var valid_594284 = query.getOrDefault("DomainName")
  valid_594284 = validateParameter(valid_594284, JString, required = true,
                                 default = nil)
  if valid_594284 != nil:
    section.add "DomainName", valid_594284
  var valid_594285 = query.getOrDefault("Version")
  valid_594285 = validateParameter(valid_594285, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594285 != nil:
    section.add "Version", valid_594285
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
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Content-Sha256", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Algorithm")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Algorithm", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Signature")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Signature", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-SignedHeaders", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Credential")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Credential", valid_594292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_GetDescribeDefaultSearchField_594280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_GetDescribeDefaultSearchField_594280;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594295 = newJObject()
  add(query_594295, "Action", newJString(Action))
  add(query_594295, "DomainName", newJString(DomainName))
  add(query_594295, "Version", newJString(Version))
  result = call_594294.call(nil, query_594295, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_594280(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_594281, base: "/",
    url: url_GetDescribeDefaultSearchField_594282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_594329 = ref object of OpenApiRestCall_593437
proc url_PostDescribeDomains_594331(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDomains_594330(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594332 = query.getOrDefault("Action")
  valid_594332 = validateParameter(valid_594332, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_594332 != nil:
    section.add "Action", valid_594332
  var valid_594333 = query.getOrDefault("Version")
  valid_594333 = validateParameter(valid_594333, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594333 != nil:
    section.add "Version", valid_594333
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
  var valid_594334 = header.getOrDefault("X-Amz-Date")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Date", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Security-Token")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Security-Token", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Content-Sha256", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Algorithm")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Algorithm", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Signature")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Signature", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-SignedHeaders", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Credential")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Credential", valid_594340
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_594341 = formData.getOrDefault("DomainNames")
  valid_594341 = validateParameter(valid_594341, JArray, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "DomainNames", valid_594341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594342: Call_PostDescribeDomains_594329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_594342.validator(path, query, header, formData, body)
  let scheme = call_594342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594342.url(scheme.get, call_594342.host, call_594342.base,
                         call_594342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594342, url, valid)

proc call*(call_594343: Call_PostDescribeDomains_594329;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594344 = newJObject()
  var formData_594345 = newJObject()
  if DomainNames != nil:
    formData_594345.add "DomainNames", DomainNames
  add(query_594344, "Action", newJString(Action))
  add(query_594344, "Version", newJString(Version))
  result = call_594343.call(nil, query_594344, nil, formData_594345, nil)

var postDescribeDomains* = Call_PostDescribeDomains_594329(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_594330, base: "/",
    url: url_PostDescribeDomains_594331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_594313 = ref object of OpenApiRestCall_593437
proc url_GetDescribeDomains_594315(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDomains_594314(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594316 = query.getOrDefault("DomainNames")
  valid_594316 = validateParameter(valid_594316, JArray, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "DomainNames", valid_594316
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594317 = query.getOrDefault("Action")
  valid_594317 = validateParameter(valid_594317, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_594317 != nil:
    section.add "Action", valid_594317
  var valid_594318 = query.getOrDefault("Version")
  valid_594318 = validateParameter(valid_594318, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594318 != nil:
    section.add "Version", valid_594318
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
  var valid_594319 = header.getOrDefault("X-Amz-Date")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Date", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Security-Token")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Security-Token", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Content-Sha256", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Algorithm")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Algorithm", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Signature")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Signature", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-SignedHeaders", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Credential")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Credential", valid_594325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594326: Call_GetDescribeDomains_594313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_594326.validator(path, query, header, formData, body)
  let scheme = call_594326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594326.url(scheme.get, call_594326.host, call_594326.base,
                         call_594326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594326, url, valid)

proc call*(call_594327: Call_GetDescribeDomains_594313;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594328 = newJObject()
  if DomainNames != nil:
    query_594328.add "DomainNames", DomainNames
  add(query_594328, "Action", newJString(Action))
  add(query_594328, "Version", newJString(Version))
  result = call_594327.call(nil, query_594328, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_594313(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_594314, base: "/",
    url: url_GetDescribeDomains_594315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_594363 = ref object of OpenApiRestCall_593437
proc url_PostDescribeIndexFields_594365(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeIndexFields_594364(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594366 = query.getOrDefault("Action")
  valid_594366 = validateParameter(valid_594366, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_594366 != nil:
    section.add "Action", valid_594366
  var valid_594367 = query.getOrDefault("Version")
  valid_594367 = validateParameter(valid_594367, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594367 != nil:
    section.add "Version", valid_594367
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
  var valid_594368 = header.getOrDefault("X-Amz-Date")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Date", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Security-Token")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Security-Token", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Content-Sha256", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-Algorithm")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-Algorithm", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Signature")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Signature", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-SignedHeaders", valid_594373
  var valid_594374 = header.getOrDefault("X-Amz-Credential")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Credential", valid_594374
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594375 = formData.getOrDefault("DomainName")
  valid_594375 = validateParameter(valid_594375, JString, required = true,
                                 default = nil)
  if valid_594375 != nil:
    section.add "DomainName", valid_594375
  var valid_594376 = formData.getOrDefault("FieldNames")
  valid_594376 = validateParameter(valid_594376, JArray, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "FieldNames", valid_594376
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594377: Call_PostDescribeIndexFields_594363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_594377.validator(path, query, header, formData, body)
  let scheme = call_594377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594377.url(scheme.get, call_594377.host, call_594377.base,
                         call_594377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594377, url, valid)

proc call*(call_594378: Call_PostDescribeIndexFields_594363; DomainName: string;
          Action: string = "DescribeIndexFields"; FieldNames: JsonNode = nil;
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Version: string (required)
  var query_594379 = newJObject()
  var formData_594380 = newJObject()
  add(formData_594380, "DomainName", newJString(DomainName))
  add(query_594379, "Action", newJString(Action))
  if FieldNames != nil:
    formData_594380.add "FieldNames", FieldNames
  add(query_594379, "Version", newJString(Version))
  result = call_594378.call(nil, query_594379, nil, formData_594380, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_594363(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_594364, base: "/",
    url: url_PostDescribeIndexFields_594365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_594346 = ref object of OpenApiRestCall_593437
proc url_GetDescribeIndexFields_594348(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeIndexFields_594347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_594349 = query.getOrDefault("FieldNames")
  valid_594349 = validateParameter(valid_594349, JArray, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "FieldNames", valid_594349
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594350 = query.getOrDefault("Action")
  valid_594350 = validateParameter(valid_594350, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_594350 != nil:
    section.add "Action", valid_594350
  var valid_594351 = query.getOrDefault("DomainName")
  valid_594351 = validateParameter(valid_594351, JString, required = true,
                                 default = nil)
  if valid_594351 != nil:
    section.add "DomainName", valid_594351
  var valid_594352 = query.getOrDefault("Version")
  valid_594352 = validateParameter(valid_594352, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594352 != nil:
    section.add "Version", valid_594352
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
  var valid_594353 = header.getOrDefault("X-Amz-Date")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Date", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Security-Token")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Security-Token", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Content-Sha256", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Algorithm")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Algorithm", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Signature")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Signature", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-SignedHeaders", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Credential")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Credential", valid_594359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594360: Call_GetDescribeIndexFields_594346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_594360.validator(path, query, header, formData, body)
  let scheme = call_594360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594360.url(scheme.get, call_594360.host, call_594360.base,
                         call_594360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594360, url, valid)

proc call*(call_594361: Call_GetDescribeIndexFields_594346; DomainName: string;
          FieldNames: JsonNode = nil; Action: string = "DescribeIndexFields";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594362 = newJObject()
  if FieldNames != nil:
    query_594362.add "FieldNames", FieldNames
  add(query_594362, "Action", newJString(Action))
  add(query_594362, "DomainName", newJString(DomainName))
  add(query_594362, "Version", newJString(Version))
  result = call_594361.call(nil, query_594362, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_594346(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_594347, base: "/",
    url: url_GetDescribeIndexFields_594348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_594398 = ref object of OpenApiRestCall_593437
proc url_PostDescribeRankExpressions_594400(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeRankExpressions_594399(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594401 = query.getOrDefault("Action")
  valid_594401 = validateParameter(valid_594401, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_594401 != nil:
    section.add "Action", valid_594401
  var valid_594402 = query.getOrDefault("Version")
  valid_594402 = validateParameter(valid_594402, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594402 != nil:
    section.add "Version", valid_594402
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
  var valid_594403 = header.getOrDefault("X-Amz-Date")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Date", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Security-Token")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Security-Token", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Content-Sha256", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Algorithm")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Algorithm", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Signature")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Signature", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-SignedHeaders", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Credential")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Credential", valid_594409
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594410 = formData.getOrDefault("DomainName")
  valid_594410 = validateParameter(valid_594410, JString, required = true,
                                 default = nil)
  if valid_594410 != nil:
    section.add "DomainName", valid_594410
  var valid_594411 = formData.getOrDefault("RankNames")
  valid_594411 = validateParameter(valid_594411, JArray, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "RankNames", valid_594411
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594412: Call_PostDescribeRankExpressions_594398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_594412.validator(path, query, header, formData, body)
  let scheme = call_594412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594412.url(scheme.get, call_594412.host, call_594412.base,
                         call_594412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594412, url, valid)

proc call*(call_594413: Call_PostDescribeRankExpressions_594398;
          DomainName: string; Action: string = "DescribeRankExpressions";
          RankNames: JsonNode = nil; Version: string = "2011-02-01"): Recallable =
  ## postDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Version: string (required)
  var query_594414 = newJObject()
  var formData_594415 = newJObject()
  add(formData_594415, "DomainName", newJString(DomainName))
  add(query_594414, "Action", newJString(Action))
  if RankNames != nil:
    formData_594415.add "RankNames", RankNames
  add(query_594414, "Version", newJString(Version))
  result = call_594413.call(nil, query_594414, nil, formData_594415, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_594398(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_594399, base: "/",
    url: url_PostDescribeRankExpressions_594400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_594381 = ref object of OpenApiRestCall_593437
proc url_GetDescribeRankExpressions_594383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeRankExpressions_594382(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_594384 = query.getOrDefault("RankNames")
  valid_594384 = validateParameter(valid_594384, JArray, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "RankNames", valid_594384
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594385 = query.getOrDefault("Action")
  valid_594385 = validateParameter(valid_594385, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_594385 != nil:
    section.add "Action", valid_594385
  var valid_594386 = query.getOrDefault("DomainName")
  valid_594386 = validateParameter(valid_594386, JString, required = true,
                                 default = nil)
  if valid_594386 != nil:
    section.add "DomainName", valid_594386
  var valid_594387 = query.getOrDefault("Version")
  valid_594387 = validateParameter(valid_594387, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594387 != nil:
    section.add "Version", valid_594387
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
  var valid_594388 = header.getOrDefault("X-Amz-Date")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-Date", valid_594388
  var valid_594389 = header.getOrDefault("X-Amz-Security-Token")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Security-Token", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-Content-Sha256", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Algorithm")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Algorithm", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Signature")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Signature", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-SignedHeaders", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Credential")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Credential", valid_594394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594395: Call_GetDescribeRankExpressions_594381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_594395.validator(path, query, header, formData, body)
  let scheme = call_594395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594395.url(scheme.get, call_594395.host, call_594395.base,
                         call_594395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594395, url, valid)

proc call*(call_594396: Call_GetDescribeRankExpressions_594381; DomainName: string;
          RankNames: JsonNode = nil; Action: string = "DescribeRankExpressions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594397 = newJObject()
  if RankNames != nil:
    query_594397.add "RankNames", RankNames
  add(query_594397, "Action", newJString(Action))
  add(query_594397, "DomainName", newJString(DomainName))
  add(query_594397, "Version", newJString(Version))
  result = call_594396.call(nil, query_594397, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_594381(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_594382, base: "/",
    url: url_GetDescribeRankExpressions_594383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_594432 = ref object of OpenApiRestCall_593437
proc url_PostDescribeServiceAccessPolicies_594434(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_594433(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594435 = query.getOrDefault("Action")
  valid_594435 = validateParameter(valid_594435, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_594435 != nil:
    section.add "Action", valid_594435
  var valid_594436 = query.getOrDefault("Version")
  valid_594436 = validateParameter(valid_594436, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594436 != nil:
    section.add "Version", valid_594436
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
  var valid_594437 = header.getOrDefault("X-Amz-Date")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Date", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Security-Token")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Security-Token", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Content-Sha256", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Algorithm")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Algorithm", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Signature")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Signature", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-SignedHeaders", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Credential")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Credential", valid_594443
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594444 = formData.getOrDefault("DomainName")
  valid_594444 = validateParameter(valid_594444, JString, required = true,
                                 default = nil)
  if valid_594444 != nil:
    section.add "DomainName", valid_594444
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594445: Call_PostDescribeServiceAccessPolicies_594432;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_594445.validator(path, query, header, formData, body)
  let scheme = call_594445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594445.url(scheme.get, call_594445.host, call_594445.base,
                         call_594445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594445, url, valid)

proc call*(call_594446: Call_PostDescribeServiceAccessPolicies_594432;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594447 = newJObject()
  var formData_594448 = newJObject()
  add(formData_594448, "DomainName", newJString(DomainName))
  add(query_594447, "Action", newJString(Action))
  add(query_594447, "Version", newJString(Version))
  result = call_594446.call(nil, query_594447, nil, formData_594448, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_594432(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_594433, base: "/",
    url: url_PostDescribeServiceAccessPolicies_594434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_594416 = ref object of OpenApiRestCall_593437
proc url_GetDescribeServiceAccessPolicies_594418(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_594417(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594419 = query.getOrDefault("Action")
  valid_594419 = validateParameter(valid_594419, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_594419 != nil:
    section.add "Action", valid_594419
  var valid_594420 = query.getOrDefault("DomainName")
  valid_594420 = validateParameter(valid_594420, JString, required = true,
                                 default = nil)
  if valid_594420 != nil:
    section.add "DomainName", valid_594420
  var valid_594421 = query.getOrDefault("Version")
  valid_594421 = validateParameter(valid_594421, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594421 != nil:
    section.add "Version", valid_594421
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
  var valid_594422 = header.getOrDefault("X-Amz-Date")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Date", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Security-Token")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Security-Token", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Content-Sha256", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Algorithm")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Algorithm", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Signature")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Signature", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-SignedHeaders", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Credential")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Credential", valid_594428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594429: Call_GetDescribeServiceAccessPolicies_594416;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_594429.validator(path, query, header, formData, body)
  let scheme = call_594429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594429.url(scheme.get, call_594429.host, call_594429.base,
                         call_594429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594429, url, valid)

proc call*(call_594430: Call_GetDescribeServiceAccessPolicies_594416;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594431 = newJObject()
  add(query_594431, "Action", newJString(Action))
  add(query_594431, "DomainName", newJString(DomainName))
  add(query_594431, "Version", newJString(Version))
  result = call_594430.call(nil, query_594431, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_594416(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_594417, base: "/",
    url: url_GetDescribeServiceAccessPolicies_594418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_594465 = ref object of OpenApiRestCall_593437
proc url_PostDescribeStemmingOptions_594467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeStemmingOptions_594466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594468 = query.getOrDefault("Action")
  valid_594468 = validateParameter(valid_594468, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_594468 != nil:
    section.add "Action", valid_594468
  var valid_594469 = query.getOrDefault("Version")
  valid_594469 = validateParameter(valid_594469, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594469 != nil:
    section.add "Version", valid_594469
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
  var valid_594470 = header.getOrDefault("X-Amz-Date")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Date", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Security-Token")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Security-Token", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Content-Sha256", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Algorithm")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Algorithm", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Signature")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Signature", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-SignedHeaders", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Credential")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Credential", valid_594476
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594477 = formData.getOrDefault("DomainName")
  valid_594477 = validateParameter(valid_594477, JString, required = true,
                                 default = nil)
  if valid_594477 != nil:
    section.add "DomainName", valid_594477
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594478: Call_PostDescribeStemmingOptions_594465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_594478.validator(path, query, header, formData, body)
  let scheme = call_594478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594478.url(scheme.get, call_594478.host, call_594478.base,
                         call_594478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594478, url, valid)

proc call*(call_594479: Call_PostDescribeStemmingOptions_594465;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594480 = newJObject()
  var formData_594481 = newJObject()
  add(formData_594481, "DomainName", newJString(DomainName))
  add(query_594480, "Action", newJString(Action))
  add(query_594480, "Version", newJString(Version))
  result = call_594479.call(nil, query_594480, nil, formData_594481, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_594465(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_594466, base: "/",
    url: url_PostDescribeStemmingOptions_594467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_594449 = ref object of OpenApiRestCall_593437
proc url_GetDescribeStemmingOptions_594451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeStemmingOptions_594450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594452 = query.getOrDefault("Action")
  valid_594452 = validateParameter(valid_594452, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_594452 != nil:
    section.add "Action", valid_594452
  var valid_594453 = query.getOrDefault("DomainName")
  valid_594453 = validateParameter(valid_594453, JString, required = true,
                                 default = nil)
  if valid_594453 != nil:
    section.add "DomainName", valid_594453
  var valid_594454 = query.getOrDefault("Version")
  valid_594454 = validateParameter(valid_594454, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594454 != nil:
    section.add "Version", valid_594454
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
  var valid_594455 = header.getOrDefault("X-Amz-Date")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Date", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Security-Token")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Security-Token", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Content-Sha256", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Algorithm")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Algorithm", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Signature")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Signature", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-SignedHeaders", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Credential")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Credential", valid_594461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594462: Call_GetDescribeStemmingOptions_594449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_594462.validator(path, query, header, formData, body)
  let scheme = call_594462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594462.url(scheme.get, call_594462.host, call_594462.base,
                         call_594462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594462, url, valid)

proc call*(call_594463: Call_GetDescribeStemmingOptions_594449; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594464 = newJObject()
  add(query_594464, "Action", newJString(Action))
  add(query_594464, "DomainName", newJString(DomainName))
  add(query_594464, "Version", newJString(Version))
  result = call_594463.call(nil, query_594464, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_594449(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_594450, base: "/",
    url: url_GetDescribeStemmingOptions_594451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_594498 = ref object of OpenApiRestCall_593437
proc url_PostDescribeStopwordOptions_594500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeStopwordOptions_594499(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594501 = query.getOrDefault("Action")
  valid_594501 = validateParameter(valid_594501, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_594501 != nil:
    section.add "Action", valid_594501
  var valid_594502 = query.getOrDefault("Version")
  valid_594502 = validateParameter(valid_594502, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594502 != nil:
    section.add "Version", valid_594502
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
  var valid_594503 = header.getOrDefault("X-Amz-Date")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Date", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Security-Token")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Security-Token", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Content-Sha256", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Algorithm")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Algorithm", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Signature")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Signature", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-SignedHeaders", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Credential")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Credential", valid_594509
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594510 = formData.getOrDefault("DomainName")
  valid_594510 = validateParameter(valid_594510, JString, required = true,
                                 default = nil)
  if valid_594510 != nil:
    section.add "DomainName", valid_594510
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594511: Call_PostDescribeStopwordOptions_594498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_594511.validator(path, query, header, formData, body)
  let scheme = call_594511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594511.url(scheme.get, call_594511.host, call_594511.base,
                         call_594511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594511, url, valid)

proc call*(call_594512: Call_PostDescribeStopwordOptions_594498;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594513 = newJObject()
  var formData_594514 = newJObject()
  add(formData_594514, "DomainName", newJString(DomainName))
  add(query_594513, "Action", newJString(Action))
  add(query_594513, "Version", newJString(Version))
  result = call_594512.call(nil, query_594513, nil, formData_594514, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_594498(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_594499, base: "/",
    url: url_PostDescribeStopwordOptions_594500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_594482 = ref object of OpenApiRestCall_593437
proc url_GetDescribeStopwordOptions_594484(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeStopwordOptions_594483(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594485 = query.getOrDefault("Action")
  valid_594485 = validateParameter(valid_594485, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_594485 != nil:
    section.add "Action", valid_594485
  var valid_594486 = query.getOrDefault("DomainName")
  valid_594486 = validateParameter(valid_594486, JString, required = true,
                                 default = nil)
  if valid_594486 != nil:
    section.add "DomainName", valid_594486
  var valid_594487 = query.getOrDefault("Version")
  valid_594487 = validateParameter(valid_594487, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594487 != nil:
    section.add "Version", valid_594487
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
  var valid_594488 = header.getOrDefault("X-Amz-Date")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Date", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Security-Token")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Security-Token", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Content-Sha256", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Algorithm")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Algorithm", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Signature")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Signature", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-SignedHeaders", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-Credential")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-Credential", valid_594494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594495: Call_GetDescribeStopwordOptions_594482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_594495.validator(path, query, header, formData, body)
  let scheme = call_594495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594495.url(scheme.get, call_594495.host, call_594495.base,
                         call_594495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594495, url, valid)

proc call*(call_594496: Call_GetDescribeStopwordOptions_594482; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594497 = newJObject()
  add(query_594497, "Action", newJString(Action))
  add(query_594497, "DomainName", newJString(DomainName))
  add(query_594497, "Version", newJString(Version))
  result = call_594496.call(nil, query_594497, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_594482(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_594483, base: "/",
    url: url_GetDescribeStopwordOptions_594484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_594531 = ref object of OpenApiRestCall_593437
proc url_PostDescribeSynonymOptions_594533(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSynonymOptions_594532(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594534 = query.getOrDefault("Action")
  valid_594534 = validateParameter(valid_594534, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_594534 != nil:
    section.add "Action", valid_594534
  var valid_594535 = query.getOrDefault("Version")
  valid_594535 = validateParameter(valid_594535, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594535 != nil:
    section.add "Version", valid_594535
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
  var valid_594536 = header.getOrDefault("X-Amz-Date")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Date", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Security-Token")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Security-Token", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Content-Sha256", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Algorithm")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Algorithm", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Signature")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Signature", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-SignedHeaders", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Credential")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Credential", valid_594542
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594543 = formData.getOrDefault("DomainName")
  valid_594543 = validateParameter(valid_594543, JString, required = true,
                                 default = nil)
  if valid_594543 != nil:
    section.add "DomainName", valid_594543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594544: Call_PostDescribeSynonymOptions_594531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_594544.validator(path, query, header, formData, body)
  let scheme = call_594544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594544.url(scheme.get, call_594544.host, call_594544.base,
                         call_594544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594544, url, valid)

proc call*(call_594545: Call_PostDescribeSynonymOptions_594531; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594546 = newJObject()
  var formData_594547 = newJObject()
  add(formData_594547, "DomainName", newJString(DomainName))
  add(query_594546, "Action", newJString(Action))
  add(query_594546, "Version", newJString(Version))
  result = call_594545.call(nil, query_594546, nil, formData_594547, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_594531(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_594532, base: "/",
    url: url_PostDescribeSynonymOptions_594533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_594515 = ref object of OpenApiRestCall_593437
proc url_GetDescribeSynonymOptions_594517(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSynonymOptions_594516(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594518 = query.getOrDefault("Action")
  valid_594518 = validateParameter(valid_594518, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_594518 != nil:
    section.add "Action", valid_594518
  var valid_594519 = query.getOrDefault("DomainName")
  valid_594519 = validateParameter(valid_594519, JString, required = true,
                                 default = nil)
  if valid_594519 != nil:
    section.add "DomainName", valid_594519
  var valid_594520 = query.getOrDefault("Version")
  valid_594520 = validateParameter(valid_594520, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594520 != nil:
    section.add "Version", valid_594520
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
  var valid_594521 = header.getOrDefault("X-Amz-Date")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Date", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Security-Token")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Security-Token", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Content-Sha256", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Algorithm")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Algorithm", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Signature")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Signature", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-SignedHeaders", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Credential")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Credential", valid_594527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594528: Call_GetDescribeSynonymOptions_594515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_594528.validator(path, query, header, formData, body)
  let scheme = call_594528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594528.url(scheme.get, call_594528.host, call_594528.base,
                         call_594528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594528, url, valid)

proc call*(call_594529: Call_GetDescribeSynonymOptions_594515; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594530 = newJObject()
  add(query_594530, "Action", newJString(Action))
  add(query_594530, "DomainName", newJString(DomainName))
  add(query_594530, "Version", newJString(Version))
  result = call_594529.call(nil, query_594530, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_594515(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_594516, base: "/",
    url: url_GetDescribeSynonymOptions_594517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_594564 = ref object of OpenApiRestCall_593437
proc url_PostIndexDocuments_594566(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostIndexDocuments_594565(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594567 = query.getOrDefault("Action")
  valid_594567 = validateParameter(valid_594567, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_594567 != nil:
    section.add "Action", valid_594567
  var valid_594568 = query.getOrDefault("Version")
  valid_594568 = validateParameter(valid_594568, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594568 != nil:
    section.add "Version", valid_594568
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
  var valid_594569 = header.getOrDefault("X-Amz-Date")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Date", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Security-Token")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Security-Token", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Content-Sha256", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Algorithm")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Algorithm", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-Signature")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Signature", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-SignedHeaders", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Credential")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Credential", valid_594575
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594576 = formData.getOrDefault("DomainName")
  valid_594576 = validateParameter(valid_594576, JString, required = true,
                                 default = nil)
  if valid_594576 != nil:
    section.add "DomainName", valid_594576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594577: Call_PostIndexDocuments_594564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_594577.validator(path, query, header, formData, body)
  let scheme = call_594577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594577.url(scheme.get, call_594577.host, call_594577.base,
                         call_594577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594577, url, valid)

proc call*(call_594578: Call_PostIndexDocuments_594564; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594579 = newJObject()
  var formData_594580 = newJObject()
  add(formData_594580, "DomainName", newJString(DomainName))
  add(query_594579, "Action", newJString(Action))
  add(query_594579, "Version", newJString(Version))
  result = call_594578.call(nil, query_594579, nil, formData_594580, nil)

var postIndexDocuments* = Call_PostIndexDocuments_594564(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_594565, base: "/",
    url: url_PostIndexDocuments_594566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_594548 = ref object of OpenApiRestCall_593437
proc url_GetIndexDocuments_594550(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIndexDocuments_594549(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594551 = query.getOrDefault("Action")
  valid_594551 = validateParameter(valid_594551, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_594551 != nil:
    section.add "Action", valid_594551
  var valid_594552 = query.getOrDefault("DomainName")
  valid_594552 = validateParameter(valid_594552, JString, required = true,
                                 default = nil)
  if valid_594552 != nil:
    section.add "DomainName", valid_594552
  var valid_594553 = query.getOrDefault("Version")
  valid_594553 = validateParameter(valid_594553, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594553 != nil:
    section.add "Version", valid_594553
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
  var valid_594554 = header.getOrDefault("X-Amz-Date")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Date", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Security-Token")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Security-Token", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Content-Sha256", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Algorithm")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Algorithm", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Signature")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Signature", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-SignedHeaders", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Credential")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Credential", valid_594560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594561: Call_GetIndexDocuments_594548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_594561.validator(path, query, header, formData, body)
  let scheme = call_594561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594561.url(scheme.get, call_594561.host, call_594561.base,
                         call_594561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594561, url, valid)

proc call*(call_594562: Call_GetIndexDocuments_594548; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594563 = newJObject()
  add(query_594563, "Action", newJString(Action))
  add(query_594563, "DomainName", newJString(DomainName))
  add(query_594563, "Version", newJString(Version))
  result = call_594562.call(nil, query_594563, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_594548(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_594549,
    base: "/", url: url_GetIndexDocuments_594550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_594598 = ref object of OpenApiRestCall_593437
proc url_PostUpdateAvailabilityOptions_594600(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateAvailabilityOptions_594599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594601 = query.getOrDefault("Action")
  valid_594601 = validateParameter(valid_594601, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_594601 != nil:
    section.add "Action", valid_594601
  var valid_594602 = query.getOrDefault("Version")
  valid_594602 = validateParameter(valid_594602, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594602 != nil:
    section.add "Version", valid_594602
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
  var valid_594603 = header.getOrDefault("X-Amz-Date")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-Date", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Security-Token")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Security-Token", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Content-Sha256", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Algorithm")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Algorithm", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Signature")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Signature", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-SignedHeaders", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Credential")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Credential", valid_594609
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594610 = formData.getOrDefault("DomainName")
  valid_594610 = validateParameter(valid_594610, JString, required = true,
                                 default = nil)
  if valid_594610 != nil:
    section.add "DomainName", valid_594610
  var valid_594611 = formData.getOrDefault("MultiAZ")
  valid_594611 = validateParameter(valid_594611, JBool, required = true, default = nil)
  if valid_594611 != nil:
    section.add "MultiAZ", valid_594611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594612: Call_PostUpdateAvailabilityOptions_594598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594612.validator(path, query, header, formData, body)
  let scheme = call_594612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594612.url(scheme.get, call_594612.host, call_594612.base,
                         call_594612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594612, url, valid)

proc call*(call_594613: Call_PostUpdateAvailabilityOptions_594598;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594614 = newJObject()
  var formData_594615 = newJObject()
  add(formData_594615, "DomainName", newJString(DomainName))
  add(formData_594615, "MultiAZ", newJBool(MultiAZ))
  add(query_594614, "Action", newJString(Action))
  add(query_594614, "Version", newJString(Version))
  result = call_594613.call(nil, query_594614, nil, formData_594615, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_594598(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_594599, base: "/",
    url: url_PostUpdateAvailabilityOptions_594600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_594581 = ref object of OpenApiRestCall_593437
proc url_GetUpdateAvailabilityOptions_594583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateAvailabilityOptions_594582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `MultiAZ` field"
  var valid_594584 = query.getOrDefault("MultiAZ")
  valid_594584 = validateParameter(valid_594584, JBool, required = true, default = nil)
  if valid_594584 != nil:
    section.add "MultiAZ", valid_594584
  var valid_594585 = query.getOrDefault("Action")
  valid_594585 = validateParameter(valid_594585, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_594585 != nil:
    section.add "Action", valid_594585
  var valid_594586 = query.getOrDefault("DomainName")
  valid_594586 = validateParameter(valid_594586, JString, required = true,
                                 default = nil)
  if valid_594586 != nil:
    section.add "DomainName", valid_594586
  var valid_594587 = query.getOrDefault("Version")
  valid_594587 = validateParameter(valid_594587, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594587 != nil:
    section.add "Version", valid_594587
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
  var valid_594588 = header.getOrDefault("X-Amz-Date")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-Date", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Security-Token")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Security-Token", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Content-Sha256", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Algorithm")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Algorithm", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Signature")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Signature", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-SignedHeaders", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Credential")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Credential", valid_594594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594595: Call_GetUpdateAvailabilityOptions_594581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_594595.validator(path, query, header, formData, body)
  let scheme = call_594595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594595.url(scheme.get, call_594595.host, call_594595.base,
                         call_594595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594595, url, valid)

proc call*(call_594596: Call_GetUpdateAvailabilityOptions_594581; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594597 = newJObject()
  add(query_594597, "MultiAZ", newJBool(MultiAZ))
  add(query_594597, "Action", newJString(Action))
  add(query_594597, "DomainName", newJString(DomainName))
  add(query_594597, "Version", newJString(Version))
  result = call_594596.call(nil, query_594597, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_594581(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_594582, base: "/",
    url: url_GetUpdateAvailabilityOptions_594583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_594633 = ref object of OpenApiRestCall_593437
proc url_PostUpdateDefaultSearchField_594635(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateDefaultSearchField_594634(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594636 = query.getOrDefault("Action")
  valid_594636 = validateParameter(valid_594636, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_594636 != nil:
    section.add "Action", valid_594636
  var valid_594637 = query.getOrDefault("Version")
  valid_594637 = validateParameter(valid_594637, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594637 != nil:
    section.add "Version", valid_594637
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
  var valid_594638 = header.getOrDefault("X-Amz-Date")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Date", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Security-Token")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Security-Token", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Content-Sha256", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Algorithm")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Algorithm", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Signature")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Signature", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-SignedHeaders", valid_594643
  var valid_594644 = header.getOrDefault("X-Amz-Credential")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-Credential", valid_594644
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DefaultSearchField` field"
  var valid_594645 = formData.getOrDefault("DefaultSearchField")
  valid_594645 = validateParameter(valid_594645, JString, required = true,
                                 default = nil)
  if valid_594645 != nil:
    section.add "DefaultSearchField", valid_594645
  var valid_594646 = formData.getOrDefault("DomainName")
  valid_594646 = validateParameter(valid_594646, JString, required = true,
                                 default = nil)
  if valid_594646 != nil:
    section.add "DomainName", valid_594646
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594647: Call_PostUpdateDefaultSearchField_594633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_594647.validator(path, query, header, formData, body)
  let scheme = call_594647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594647.url(scheme.get, call_594647.host, call_594647.base,
                         call_594647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594647, url, valid)

proc call*(call_594648: Call_PostUpdateDefaultSearchField_594633;
          DefaultSearchField: string; DomainName: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594649 = newJObject()
  var formData_594650 = newJObject()
  add(formData_594650, "DefaultSearchField", newJString(DefaultSearchField))
  add(formData_594650, "DomainName", newJString(DomainName))
  add(query_594649, "Action", newJString(Action))
  add(query_594649, "Version", newJString(Version))
  result = call_594648.call(nil, query_594649, nil, formData_594650, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_594633(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_594634, base: "/",
    url: url_PostUpdateDefaultSearchField_594635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_594616 = ref object of OpenApiRestCall_593437
proc url_GetUpdateDefaultSearchField_594618(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateDefaultSearchField_594617(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594619 = query.getOrDefault("Action")
  valid_594619 = validateParameter(valid_594619, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_594619 != nil:
    section.add "Action", valid_594619
  var valid_594620 = query.getOrDefault("DomainName")
  valid_594620 = validateParameter(valid_594620, JString, required = true,
                                 default = nil)
  if valid_594620 != nil:
    section.add "DomainName", valid_594620
  var valid_594621 = query.getOrDefault("DefaultSearchField")
  valid_594621 = validateParameter(valid_594621, JString, required = true,
                                 default = nil)
  if valid_594621 != nil:
    section.add "DefaultSearchField", valid_594621
  var valid_594622 = query.getOrDefault("Version")
  valid_594622 = validateParameter(valid_594622, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594622 != nil:
    section.add "Version", valid_594622
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
  var valid_594623 = header.getOrDefault("X-Amz-Date")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Date", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Security-Token")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Security-Token", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Content-Sha256", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Algorithm")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Algorithm", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Signature")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Signature", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-SignedHeaders", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Credential")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Credential", valid_594629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594630: Call_GetUpdateDefaultSearchField_594616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_594630.validator(path, query, header, formData, body)
  let scheme = call_594630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594630.url(scheme.get, call_594630.host, call_594630.base,
                         call_594630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594630, url, valid)

proc call*(call_594631: Call_GetUpdateDefaultSearchField_594616;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: string (required)
  var query_594632 = newJObject()
  add(query_594632, "Action", newJString(Action))
  add(query_594632, "DomainName", newJString(DomainName))
  add(query_594632, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_594632, "Version", newJString(Version))
  result = call_594631.call(nil, query_594632, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_594616(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_594617, base: "/",
    url: url_GetUpdateDefaultSearchField_594618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_594668 = ref object of OpenApiRestCall_593437
proc url_PostUpdateServiceAccessPolicies_594670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_594669(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594671 = query.getOrDefault("Action")
  valid_594671 = validateParameter(valid_594671, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_594671 != nil:
    section.add "Action", valid_594671
  var valid_594672 = query.getOrDefault("Version")
  valid_594672 = validateParameter(valid_594672, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594672 != nil:
    section.add "Version", valid_594672
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
  var valid_594673 = header.getOrDefault("X-Amz-Date")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Date", valid_594673
  var valid_594674 = header.getOrDefault("X-Amz-Security-Token")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Security-Token", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Content-Sha256", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-Algorithm")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Algorithm", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Signature")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Signature", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-SignedHeaders", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Credential")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Credential", valid_594679
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594680 = formData.getOrDefault("DomainName")
  valid_594680 = validateParameter(valid_594680, JString, required = true,
                                 default = nil)
  if valid_594680 != nil:
    section.add "DomainName", valid_594680
  var valid_594681 = formData.getOrDefault("AccessPolicies")
  valid_594681 = validateParameter(valid_594681, JString, required = true,
                                 default = nil)
  if valid_594681 != nil:
    section.add "AccessPolicies", valid_594681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594682: Call_PostUpdateServiceAccessPolicies_594668;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_594682.validator(path, query, header, formData, body)
  let scheme = call_594682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594682.url(scheme.get, call_594682.host, call_594682.base,
                         call_594682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594682, url, valid)

proc call*(call_594683: Call_PostUpdateServiceAccessPolicies_594668;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594684 = newJObject()
  var formData_594685 = newJObject()
  add(formData_594685, "DomainName", newJString(DomainName))
  add(formData_594685, "AccessPolicies", newJString(AccessPolicies))
  add(query_594684, "Action", newJString(Action))
  add(query_594684, "Version", newJString(Version))
  result = call_594683.call(nil, query_594684, nil, formData_594685, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_594668(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_594669, base: "/",
    url: url_PostUpdateServiceAccessPolicies_594670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_594651 = ref object of OpenApiRestCall_593437
proc url_GetUpdateServiceAccessPolicies_594653(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_594652(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594654 = query.getOrDefault("Action")
  valid_594654 = validateParameter(valid_594654, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_594654 != nil:
    section.add "Action", valid_594654
  var valid_594655 = query.getOrDefault("AccessPolicies")
  valid_594655 = validateParameter(valid_594655, JString, required = true,
                                 default = nil)
  if valid_594655 != nil:
    section.add "AccessPolicies", valid_594655
  var valid_594656 = query.getOrDefault("DomainName")
  valid_594656 = validateParameter(valid_594656, JString, required = true,
                                 default = nil)
  if valid_594656 != nil:
    section.add "DomainName", valid_594656
  var valid_594657 = query.getOrDefault("Version")
  valid_594657 = validateParameter(valid_594657, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594657 != nil:
    section.add "Version", valid_594657
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
  var valid_594658 = header.getOrDefault("X-Amz-Date")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Date", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-Security-Token")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Security-Token", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Content-Sha256", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Algorithm")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Algorithm", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Signature")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Signature", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-SignedHeaders", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Credential")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Credential", valid_594664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594665: Call_GetUpdateServiceAccessPolicies_594651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_594665.validator(path, query, header, formData, body)
  let scheme = call_594665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594665.url(scheme.get, call_594665.host, call_594665.base,
                         call_594665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594665, url, valid)

proc call*(call_594666: Call_GetUpdateServiceAccessPolicies_594651;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   Action: string (required)
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594667 = newJObject()
  add(query_594667, "Action", newJString(Action))
  add(query_594667, "AccessPolicies", newJString(AccessPolicies))
  add(query_594667, "DomainName", newJString(DomainName))
  add(query_594667, "Version", newJString(Version))
  result = call_594666.call(nil, query_594667, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_594651(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_594652, base: "/",
    url: url_GetUpdateServiceAccessPolicies_594653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_594703 = ref object of OpenApiRestCall_593437
proc url_PostUpdateStemmingOptions_594705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateStemmingOptions_594704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594706 = query.getOrDefault("Action")
  valid_594706 = validateParameter(valid_594706, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_594706 != nil:
    section.add "Action", valid_594706
  var valid_594707 = query.getOrDefault("Version")
  valid_594707 = validateParameter(valid_594707, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594707 != nil:
    section.add "Version", valid_594707
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
  var valid_594708 = header.getOrDefault("X-Amz-Date")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-Date", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Security-Token")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Security-Token", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Content-Sha256", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Algorithm")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Algorithm", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Signature")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Signature", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-SignedHeaders", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Credential")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Credential", valid_594714
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594715 = formData.getOrDefault("DomainName")
  valid_594715 = validateParameter(valid_594715, JString, required = true,
                                 default = nil)
  if valid_594715 != nil:
    section.add "DomainName", valid_594715
  var valid_594716 = formData.getOrDefault("Stems")
  valid_594716 = validateParameter(valid_594716, JString, required = true,
                                 default = nil)
  if valid_594716 != nil:
    section.add "Stems", valid_594716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594717: Call_PostUpdateStemmingOptions_594703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_594717.validator(path, query, header, formData, body)
  let scheme = call_594717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594717.url(scheme.get, call_594717.host, call_594717.base,
                         call_594717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594717, url, valid)

proc call*(call_594718: Call_PostUpdateStemmingOptions_594703; DomainName: string;
          Stems: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   Version: string (required)
  var query_594719 = newJObject()
  var formData_594720 = newJObject()
  add(formData_594720, "DomainName", newJString(DomainName))
  add(query_594719, "Action", newJString(Action))
  add(formData_594720, "Stems", newJString(Stems))
  add(query_594719, "Version", newJString(Version))
  result = call_594718.call(nil, query_594719, nil, formData_594720, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_594703(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_594704, base: "/",
    url: url_PostUpdateStemmingOptions_594705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_594686 = ref object of OpenApiRestCall_593437
proc url_GetUpdateStemmingOptions_594688(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateStemmingOptions_594687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594689 = query.getOrDefault("Action")
  valid_594689 = validateParameter(valid_594689, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_594689 != nil:
    section.add "Action", valid_594689
  var valid_594690 = query.getOrDefault("Stems")
  valid_594690 = validateParameter(valid_594690, JString, required = true,
                                 default = nil)
  if valid_594690 != nil:
    section.add "Stems", valid_594690
  var valid_594691 = query.getOrDefault("DomainName")
  valid_594691 = validateParameter(valid_594691, JString, required = true,
                                 default = nil)
  if valid_594691 != nil:
    section.add "DomainName", valid_594691
  var valid_594692 = query.getOrDefault("Version")
  valid_594692 = validateParameter(valid_594692, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594692 != nil:
    section.add "Version", valid_594692
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
  var valid_594693 = header.getOrDefault("X-Amz-Date")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-Date", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Security-Token")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Security-Token", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Content-Sha256", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Algorithm")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Algorithm", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Signature")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Signature", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-SignedHeaders", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Credential")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Credential", valid_594699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594700: Call_GetUpdateStemmingOptions_594686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_594700.validator(path, query, header, formData, body)
  let scheme = call_594700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594700.url(scheme.get, call_594700.host, call_594700.base,
                         call_594700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594700, url, valid)

proc call*(call_594701: Call_GetUpdateStemmingOptions_594686; Stems: string;
          DomainName: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594702 = newJObject()
  add(query_594702, "Action", newJString(Action))
  add(query_594702, "Stems", newJString(Stems))
  add(query_594702, "DomainName", newJString(DomainName))
  add(query_594702, "Version", newJString(Version))
  result = call_594701.call(nil, query_594702, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_594686(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_594687, base: "/",
    url: url_GetUpdateStemmingOptions_594688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_594738 = ref object of OpenApiRestCall_593437
proc url_PostUpdateStopwordOptions_594740(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateStopwordOptions_594739(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594741 = query.getOrDefault("Action")
  valid_594741 = validateParameter(valid_594741, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_594741 != nil:
    section.add "Action", valid_594741
  var valid_594742 = query.getOrDefault("Version")
  valid_594742 = validateParameter(valid_594742, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594742 != nil:
    section.add "Version", valid_594742
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
  var valid_594743 = header.getOrDefault("X-Amz-Date")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Date", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Security-Token")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Security-Token", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Content-Sha256", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Algorithm")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Algorithm", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Signature")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Signature", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-SignedHeaders", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-Credential")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-Credential", valid_594749
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_594750 = formData.getOrDefault("Stopwords")
  valid_594750 = validateParameter(valid_594750, JString, required = true,
                                 default = nil)
  if valid_594750 != nil:
    section.add "Stopwords", valid_594750
  var valid_594751 = formData.getOrDefault("DomainName")
  valid_594751 = validateParameter(valid_594751, JString, required = true,
                                 default = nil)
  if valid_594751 != nil:
    section.add "DomainName", valid_594751
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594752: Call_PostUpdateStopwordOptions_594738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_594752.validator(path, query, header, formData, body)
  let scheme = call_594752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594752.url(scheme.get, call_594752.host, call_594752.base,
                         call_594752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594752, url, valid)

proc call*(call_594753: Call_PostUpdateStopwordOptions_594738; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594754 = newJObject()
  var formData_594755 = newJObject()
  add(formData_594755, "Stopwords", newJString(Stopwords))
  add(formData_594755, "DomainName", newJString(DomainName))
  add(query_594754, "Action", newJString(Action))
  add(query_594754, "Version", newJString(Version))
  result = call_594753.call(nil, query_594754, nil, formData_594755, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_594738(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_594739, base: "/",
    url: url_PostUpdateStopwordOptions_594740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_594721 = ref object of OpenApiRestCall_593437
proc url_GetUpdateStopwordOptions_594723(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateStopwordOptions_594722(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594724 = query.getOrDefault("Action")
  valid_594724 = validateParameter(valid_594724, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_594724 != nil:
    section.add "Action", valid_594724
  var valid_594725 = query.getOrDefault("Stopwords")
  valid_594725 = validateParameter(valid_594725, JString, required = true,
                                 default = nil)
  if valid_594725 != nil:
    section.add "Stopwords", valid_594725
  var valid_594726 = query.getOrDefault("DomainName")
  valid_594726 = validateParameter(valid_594726, JString, required = true,
                                 default = nil)
  if valid_594726 != nil:
    section.add "DomainName", valid_594726
  var valid_594727 = query.getOrDefault("Version")
  valid_594727 = validateParameter(valid_594727, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594727 != nil:
    section.add "Version", valid_594727
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
  var valid_594728 = header.getOrDefault("X-Amz-Date")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Date", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Security-Token")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Security-Token", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Content-Sha256", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Algorithm")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Algorithm", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Signature")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Signature", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-SignedHeaders", valid_594733
  var valid_594734 = header.getOrDefault("X-Amz-Credential")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-Credential", valid_594734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594735: Call_GetUpdateStopwordOptions_594721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_594735.validator(path, query, header, formData, body)
  let scheme = call_594735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594735.url(scheme.get, call_594735.host, call_594735.base,
                         call_594735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594735, url, valid)

proc call*(call_594736: Call_GetUpdateStopwordOptions_594721; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Action: string (required)
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594737 = newJObject()
  add(query_594737, "Action", newJString(Action))
  add(query_594737, "Stopwords", newJString(Stopwords))
  add(query_594737, "DomainName", newJString(DomainName))
  add(query_594737, "Version", newJString(Version))
  result = call_594736.call(nil, query_594737, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_594721(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_594722, base: "/",
    url: url_GetUpdateStopwordOptions_594723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_594773 = ref object of OpenApiRestCall_593437
proc url_PostUpdateSynonymOptions_594775(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateSynonymOptions_594774(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594776 = query.getOrDefault("Action")
  valid_594776 = validateParameter(valid_594776, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_594776 != nil:
    section.add "Action", valid_594776
  var valid_594777 = query.getOrDefault("Version")
  valid_594777 = validateParameter(valid_594777, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594777 != nil:
    section.add "Version", valid_594777
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
  var valid_594778 = header.getOrDefault("X-Amz-Date")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Date", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Security-Token")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Security-Token", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Content-Sha256", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Algorithm")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Algorithm", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Signature")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Signature", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-SignedHeaders", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Credential")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Credential", valid_594784
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_594785 = formData.getOrDefault("DomainName")
  valid_594785 = validateParameter(valid_594785, JString, required = true,
                                 default = nil)
  if valid_594785 != nil:
    section.add "DomainName", valid_594785
  var valid_594786 = formData.getOrDefault("Synonyms")
  valid_594786 = validateParameter(valid_594786, JString, required = true,
                                 default = nil)
  if valid_594786 != nil:
    section.add "Synonyms", valid_594786
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594787: Call_PostUpdateSynonymOptions_594773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_594787.validator(path, query, header, formData, body)
  let scheme = call_594787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594787.url(scheme.get, call_594787.host, call_594787.base,
                         call_594787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594787, url, valid)

proc call*(call_594788: Call_PostUpdateSynonymOptions_594773; DomainName: string;
          Synonyms: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594789 = newJObject()
  var formData_594790 = newJObject()
  add(formData_594790, "DomainName", newJString(DomainName))
  add(formData_594790, "Synonyms", newJString(Synonyms))
  add(query_594789, "Action", newJString(Action))
  add(query_594789, "Version", newJString(Version))
  result = call_594788.call(nil, query_594789, nil, formData_594790, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_594773(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_594774, base: "/",
    url: url_PostUpdateSynonymOptions_594775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_594756 = ref object of OpenApiRestCall_593437
proc url_GetUpdateSynonymOptions_594758(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateSynonymOptions_594757(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594759 = query.getOrDefault("Action")
  valid_594759 = validateParameter(valid_594759, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_594759 != nil:
    section.add "Action", valid_594759
  var valid_594760 = query.getOrDefault("Synonyms")
  valid_594760 = validateParameter(valid_594760, JString, required = true,
                                 default = nil)
  if valid_594760 != nil:
    section.add "Synonyms", valid_594760
  var valid_594761 = query.getOrDefault("DomainName")
  valid_594761 = validateParameter(valid_594761, JString, required = true,
                                 default = nil)
  if valid_594761 != nil:
    section.add "DomainName", valid_594761
  var valid_594762 = query.getOrDefault("Version")
  valid_594762 = validateParameter(valid_594762, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_594762 != nil:
    section.add "Version", valid_594762
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
  var valid_594763 = header.getOrDefault("X-Amz-Date")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Date", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Security-Token")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Security-Token", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Content-Sha256", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-Algorithm")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Algorithm", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Signature")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Signature", valid_594767
  var valid_594768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-SignedHeaders", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Credential")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Credential", valid_594769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594770: Call_GetUpdateSynonymOptions_594756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_594770.validator(path, query, header, formData, body)
  let scheme = call_594770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594770.url(scheme.get, call_594770.host, call_594770.base,
                         call_594770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594770, url, valid)

proc call*(call_594771: Call_GetUpdateSynonymOptions_594756; Synonyms: string;
          DomainName: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   Action: string (required)
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_594772 = newJObject()
  add(query_594772, "Action", newJString(Action))
  add(query_594772, "Synonyms", newJString(Synonyms))
  add(query_594772, "DomainName", newJString(DomainName))
  add(query_594772, "Version", newJString(Version))
  result = call_594771.call(nil, query_594772, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_594756(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_594757, base: "/",
    url: url_GetUpdateSynonymOptions_594758, schemes: {Scheme.Https, Scheme.Http})
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
